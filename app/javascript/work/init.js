import { mountSvelteComponents } from '../mount.js';
import { annotation_channel_connect } from '../channels/annotation_channel';
import { active_docid } from '../lib/ldcjs/waveform/stores';
import { set_ldc, init_nodes } from './other';
// import { getp, postp } from '../lib/ldcjs/getp';
import { refreshToken, s3url, getSignedUrlPromise } from '../lib/ldcjs/aws_helper';
// import { fromCognitoIdentity } from "@aws-sdk/credential-provider-cognito-identity";
// import { CognitoIdentityClient } from "@aws-sdk/client-cognito-identity";
// import { TranscribeClient } from "@aws-sdk/client-transcribe";
// import { S3Client, GetObjectCommand, HeadObjectCommand, ListObjectsV2Command, PutObjectCommand } from "@aws-sdk/client-s3";
// import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
function init(ldc){
  annotation_channel_connect(ldc);

//   refreshToken({
//     fromCognitoIdentity,
//     CognitoIdentityClient,
//     TranscribeClient,
//     S3Client,
//     GetObjectCommand,
//     HeadObjectCommand,
//     ListObjectsV2Command,
//     PutObjectCommand,
//     getSignedUrl
// });
  const obj = ldc.obj2;
  set_ldc(ldc);
  if(obj.xlass_def_id) init_nodes();
  if(!ldc.resources.urls) ldc.resources.urls = {}; //ldc.resources.manifest.urls;
  // keys can be 24 or 28?
  if(obj.source.uid.match(/^\w{24,28}$/)){
    // alert(Object.keys(ldc.resources.urls))
    if(obj.filename == obj.source.uid) obj.filename = `filename_for_${obj.source.uid}`;
    active_docid.update( () => obj.filename );
    ldc.resources.urls[obj.filename] = ldc.resources.urls[obj.source.uid];
    ldc.resources.original_s3_key = obj.source.uid;
    console.log(JSON.stringify(ldc.resources))
    delete ldc.resources.urls[obj.source.uid];
  }
  else{
    set_urls(obj.source.uid).then((o) => {
      ldc.maino = o;
      if(o) active_docid.set(o.wav);
    });
  }
  function set_urls(kk){
    const k = kk.replace(/\s+$/, '');
    const found = s3url(k);
    if(found.bucket) {
        return set_urls3(found, k);
        // .then( (x) => signed_url_for_audio(found.bucket, found.key, urls, x) )
        // .then( () => k );
    }
    else{
        return set_urls2(k);
    }
}
function set_urls3(found, k){
    ldc.resources.bucket = found.bucket;
    const urls = ldc.resources.urls;
    return Promise.resolve( 
        k.match(/wav$/) ? { wav: k } :
        getSignedUrlPromise(found.bucket, found.key)
        .then( getp )
        .then(function(d){

            const o = {};

            // resolve this one in parallel
            if(d.tsv){
                let found = s3url(d.tsv);
                o.transcript = getSignedUrlPromise(found.bucket, found.key)
                .then( getp )
                .then(function(d){
                    return {
                        use_transcript: 'tsv',
                        found_transcript: d
                    };
                });
            }

            // resolve this one in parallel
            if(d.tdf){
                let found = s3url(d.tdf);
                o.transcript = getSignedUrlPromise(found.bucket, found.key)
                .then( getp )
                .then(function(d){
                    return {
                        use_transcript: 'tdf',
                        found_transcript: d
                    };
                });
            }

            // resolve this one in parallel
            if(d.sad_with_aws){
                let found = s3url(d.sad_with_aws);
                o.transcript = getSignedUrlPromise(found.bucket, found.key)
                .then( getp )
                .then(function(d){
                    return {
                        use_transcript: 'sad_with_aws',
                        found_transcript: d
                    };
                });
            }

            if(d.wav){
              o.wav = d.wav;
              return o;
                // active_docid.update( () => d.wav );
                // found = s3url(d.wav);
                // return signed_url_for_audio(found.bucket, found.key, urls, d.wav)
                // .then( (x) => {
                //     o.wav = x.wav;
                //     // o.wav_url = urls[x.wav];
                //     return o;
                // });
            }
            else{
                return o;
            }
            
        })
        .catch( () => alert('error, try refreshing') )
    );
}
function signed_url_for_audio(bucket, key, urls, k) {
  return getSignedUrlPromise(bucket, key)
  .then(function(data){
      urls[k] = data;
  })
  .then( () => { return { wav: k, wav_url: urls[k] } } );
}
function set_urls2(k){
    return Promise.resolve({});
  const urls = ldc.resources.urls;
  if(k.match(/^http/)) urls[k] = k;
  if(!urls[k]) return;
  if(urls[k].substr(0, 2) === 's3'){
      if(urls[k] === 's3'){
          return alert('missing bucket');
      }
      else{
          ldc.resources.bucket = urls[k].replace(/^s3(:\/\/)?/, '').replace(/\/.+/, '');
          const bucket = ldc.resources.bucket;
          let key = k.replace(bucket + '/', '').replace('filename_for_', '');
          if(ldc.resources.original_s3_key) key = ldc.resources.original_s3_key;
          return signed_url_for_audio(bucket, key, urls, k);
          // .then( () => k );
      }
  }
  else{
      return Promise.resolve( { wav: k, wav_url: urls[k] } );
  }
 }
    // ns.main = mount(Main, {
    //   target: $('.view')[0],
    //   props: h
    // });
    mountSvelteComponents()


    // return p;
}

export { init }