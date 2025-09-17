class AzureTranscriptionController < ApplicationController
  # Start transcription job and return immediately
  def create
    return render json: { error: 'Not authenticated' }, status: 401 unless authenticated?
    
    blob_name = params[:blob_name]
    return render json: { error: 'blob_name required' }, status: 400 if blob_name.blank?

    begin
      # Get Azure credentials
      storage_account_name = Rails.application.credentials.dig(:azure_storage, :storage_account_name)
      sas_token = Rails.application.credentials.dig(:azure_storage, :sas_token)
      container_name = Rails.application.credentials.dig(:azure_storage, :container)
      speech_key = Rails.application.credentials.dig(:azure_speech, :key)
      speech_region = Rails.application.credentials.dig(:azure_speech, :region)
      
      return render json: { error: 'Azure credentials not configured' }, status: 500 if storage_account_name.blank? || sas_token.blank? || container_name.blank?
      return render json: { error: 'Azure Speech credentials not configured' }, status: 500 if speech_key.blank? || speech_region.blank?
      
      # Construct the audio file URL
      audio_url = "https://#{storage_account_name}.blob.core.windows.net/#{container_name}/#{blob_name}"
      audio_url += "#{sas_token.start_with?('?') ? sas_token : '?' + sas_token}"
      
      # Start transcription job asynchronously
      job_id = start_transcription_job(audio_url, speech_key, speech_region)
      
      render json: {
        job_id: job_id,
        blob_name: blob_name,
        status: 'started',
        message: 'Transcription job started. Use /azure_transcribe/status/:job_id to check progress.'
      }
      
    rescue => e
      Rails.logger.error "Azure transcription error: #{e.message}"
      Rails.logger.error e.backtrace
      render json: { 
        error: 'Failed to start transcription', 
        details: e.message
      }, status: 500
    end
  end

  # Check transcription job status
  def status
    return render json: { error: 'Not authenticated' }, status: 401 unless authenticated?
    
    job_id = params[:job_id]
    return render json: { error: 'job_id required' }, status: 400 if job_id.blank?

    begin
      speech_key = Rails.application.credentials.dig(:azure_speech, :key)
      speech_region = Rails.application.credentials.dig(:azure_speech, :region)
      
      return render json: { error: 'Azure Speech credentials not configured' }, status: 500 if speech_key.blank? || speech_region.blank?
      
      result = check_transcription_status(job_id, speech_key, speech_region)
      
      render json: result
      
    rescue => e
      Rails.logger.error "Azure transcription status error: #{e.message}"
      render json: { 
        error: 'Failed to check transcription status', 
        details: e.message
      }, status: 500
    end
  end

  private

  def start_transcription_job(audio_url, speech_key, speech_region)
    batch_api_url = "https://#{speech_region}.api.cognitive.microsoft.com/speechtotext/v3.1/transcriptions"
    
    http = Net::HTTP.new(URI(batch_api_url).host, 443)
    http.use_ssl = true
    http.read_timeout = 30 # 30 second timeout for API calls
    
    request = Net::HTTP::Post.new(batch_api_url)
    request['Ocp-Apim-Subscription-Key'] = speech_key
    request['Content-Type'] = 'application/json'
    
    request.body = {
      'contentUrls' => [audio_url],
      'locale' => 'en-US',
      'displayName' => "Audio Transcription #{Time.current.to_i}",
      'properties' => {
        'diarizationEnabled' => false,
        'punctuationMode' => 'DictatedAndAutomatic',
        'profanityFilterMode' => 'None'
      }
    }.to_json
    
    Rails.logger.info "Creating batch transcription job..."
    response = http.request(request)
    
    unless response.code.to_i == 201
      Rails.logger.error "Failed to create transcription job: #{response.code} - #{response.body}"
      raise "Error creating transcription job: #{response.code} - #{response.body}"
    end
    
    job_data = JSON.parse(response.body)
    job_url = job_data['self']
    Rails.logger.info "Transcription job created: #{job_url}"
    
    # Extract job ID from URL
    job_url.split('/').last
  end

  def check_transcription_status(job_id, speech_key, speech_region)
    job_url = "https://#{speech_region}.api.cognitive.microsoft.com/speechtotext/v3.1/transcriptions/#{job_id}"
    
    http = Net::HTTP.new(URI(job_url).host, 443)
    http.use_ssl = true
    http.read_timeout = 30
    
    status_request = Net::HTTP::Get.new(job_url)
    status_request['Ocp-Apim-Subscription-Key'] = speech_key
    status_response = http.request(status_request)
    
    unless status_response.code.to_i == 200
      Rails.logger.error "Failed to get job status: #{status_response.code}"
      return { error: "Error checking transcription status: #{status_response.code}" }
    end
    
    status_data = JSON.parse(status_response.body)
    Rails.logger.info "Job status: #{status_data['status']}"
    
    case status_data['status']
    when 'Succeeded'
      # Get transcription results
      transcription_text = get_transcription_result(status_data, speech_key)
      {
        status: 'completed',
        job_id: job_id,
        transcription: transcription_text
      }
    when 'Failed'
      {
        status: 'failed',
        job_id: job_id,
        error: status_data['statusMessage'] || 'Unknown error'
      }
    when 'Running', 'NotStarted'
      {
        status: 'processing',
        job_id: job_id,
        message: 'Transcription in progress...'
      }
    else
      {
        status: 'unknown',
        job_id: job_id,
        azure_status: status_data['status']
      }
    end
  end

  def get_transcription_result(status_data, speech_key)
    files_url = status_data['links']['files']
    Rails.logger.info "Getting files from: #{files_url}"
    
    http = Net::HTTP.new(URI(files_url).host, 443)
    http.use_ssl = true
    http.read_timeout = 30
    
    files_request = Net::HTTP::Get.new(files_url)
    files_request['Ocp-Apim-Subscription-Key'] = speech_key
    files_response = http.request(files_request)
    
    return "Failed to get transcription files: #{files_response.code}" unless files_response.code.to_i == 200
    
    files_data = JSON.parse(files_response.body)
    result_file = files_data['values']&.find { |f| f['kind'] == 'Transcription' }
    
    return "No transcription file found in results" unless result_file&.dig('links', 'contentUrl')
    
    # Download transcription result
    content_url = result_file['links']['contentUrl']
    content_uri = URI(content_url)
    content_http = Net::HTTP.new(content_uri.host, content_uri.port)
    content_http.use_ssl = content_uri.scheme == 'https'
    content_http.read_timeout = 30
    
    result_request = Net::HTTP::Get.new(content_uri.path + (content_uri.query ? "?#{content_uri.query}" : ""))
    result_request['Ocp-Apim-Subscription-Key'] = speech_key
    result_response = content_http.request(result_request)
    
    return "Failed to download transcription results: #{result_response.code}" unless result_response.code.to_i == 200
    
    transcription_data = JSON.parse(result_response.body)
    
    # Extract text from response
    if transcription_data['combinedRecognizedPhrases']&.any?
      return transcription_data['combinedRecognizedPhrases'].first['display']
    elsif transcription_data['recognizedPhrases']&.any?
      return transcription_data['recognizedPhrases'].map { |p| p['nBest']&.first&.dig('display') }.compact.join(' ')
    else
      return "No transcription text found in response data"
    end
  end
end