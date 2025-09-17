# README

This is a stripped down app that was used specifically to test an Azure deployment.  It uses [kamal](https://kamal-deploy.org/) for deployment, and we usually use VMs on AWS, but any available linux machine should work.

# VM

The VM has to allow ssh, http, and https traffic, and docker must be installed.  The relevant user must be able to use docker, so in this deployment, `usermod -aG docker azureuser` was run on the VM after installing docker.  If not using the `azureuser` user, change the name in `deploy/config.yml`.  If using `root`, that section can be commented out.  Before installing docker, you probably need these linux packages installed:

    apt-transport-https
    ca-certificates
    curl
    gnupg
    lsb-release

You should also add a public key for your local user to the .ssh directory on the VM to allow for seamless login during deployment.

# Azure Storage and Transcription

The azure credentials in this repo have this structure:

    azure_storage:
      storage_account_name: foo
      sas_token: bar
      container: baz
    azure_speech:
      key: foo
      region: bar

The credentials are encrypted in `config/credentials.yml.enc`, and can't be accessed without `config/master.key`, which is not checked into the repo.  You should delete the credentials file and run `bin/rails credentials:edit` (set your editor with the `EDITOR` environment variable), which will create those two files.  Enter the appropriate credentials, and save.  You should take this step before trying to deploy, although the credentials don't need to be correct just to test deployment, so you could postpone configuring storage and transcription.

# Kamal

Kamal takes care of the deployment details, using docker.  You'll need to use dockerhub or some alternative.  You need to create an image on dockerhub, and put your account user and image name in `deploy/config.yml`.  Create a read/write access token on dockerhub.  If the the token was `foo`, you could add it to your shell with

    export KAMAL_REGISTRY_PASSWORD=foo

The web server and host in the config file should have the public IP, or the host/domain name, of the VM.  After these details are set, you can deploy with `bin/kamal setup`, and deployments after that with `bin/kamal deploy`.  To summarize the kamal config changes, you need to change the image name on line 5, the VM address on lines 10 and 22, the username on line 28, and possibly the username on line 92.

# Account Creation

When creating an account, the flash message will say to check for an account activation email.  Since email hasn't been configured, you won't receive an email, but the activation step isn't necessary for this simplified app, and you can go ahead and log in.  In the full version of this app, email would need to be configured so activation is possible.

# Usage

The running app has limited functionality.  You should see an `Audio` tab, where you can put the object name of a wav file in Azure storage.  If you've configured storage and transcription (see above), you should be able to play back the audio and retrieve its transcription.

