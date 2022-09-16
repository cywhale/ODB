#Prerequisites: Follow biigle official steps https://biigle-admin-documentation.readthedocs.io/gpu/
#Backup your .env, .dockerfiles, .yaml, ...first
sudo git pull upstream master
sudo git fetch --all
sudo git checkout -b gpu origin/gpu
sudo git branch
#* gpu
#  master

git checkout master  ## switch to master
sudo git pull --rebase
sudo git merge gpu

sudo git status #check unmerged status
## Just examples to solve conflict
sudo nano build/config/filesystems.php
sudo git checkout --ours build/.env.example

sudo git add .
sudo git commit -m "try resolved merge gpu branch"

#Note in .env, about MAIA link with gpu
MAIA_TRAINING_PROPOSAL_STORAGE_DISK=maia-tp
MAIA_ANNOTATION_CANDIDATE_STORAGE_DISK=maia-ac
MAIA_REQUEST_QUEUE=gpu
MAIA_REQUEST_CONNECTION=gpu
MAIA_RESPONSE_QUEUE=default
MAIA_RESPONSE_CONNECTION=redis
MAIA_AVAILABLE_BYTES=15E+9
MAIA_MAX_WORKERS=10
#add
USER_ID=1000
GROUP_ID=1000

#install tensorflow 2.5.3
pip install tensorflow==2.5.3
docker pull tensorflow/tensorflow:latest-gpu #(and modify gpu-worker.dockerfile for this version, not 2.5.3-gpu) #for example, I need to modify as:
FROM tensorflow/tensorflow:latest-gpu

# according gpu-worker.dockerfile, modify available php8.0 version in ARG PHP_VERSION
# Find versions here: https://launchpad.net/~ondrej/+archive/ubuntu/php, query in this web Package name contains: php8.0, and get version
# Here, for example (202209) I got to modify as: 
ARG PHP_VERSION=1:8.0.22-1+ubuntu20.04.1+deb.sury.org+1
#then run 
cd build && sudo ./build.sh
#Problem about docker-compose.yaml and ./artisan migrate
# https://github.com/biigle/core/discussions/482


