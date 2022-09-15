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
