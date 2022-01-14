# Biigle
# https://github.com/biigle/distribution
# schema: https://biigle.github.io/schema/tables/users.html

# change .env build/.env and docker-compose.yaml (port) settings
# after build and ./artisan migrate, ./artisan user:new
./artisan tinker
$user = new User;
$user->firstname = 'userxxx';
$user->lastname = 'ooo';
$user->email = 'userxxx@email';
$user->password = Hash::make('PASSWD');
$user->role_id = 2;
$user->uuid = Str::uuid('3');
$user->id = 3;
$user->save();
# -------------- role_id = 2 is 'Editor', id is a series integer ----
# It strangely some uncetain bugs when add users using GUI interface

# MBARI vars-annotation
# https://mbari-media-management.github.io/vars-annotation/resources/markdown/BUILD.html
# install JDK v.14 but JAVA set version 11
sdk install gradle 6.3

# Bugs or some unknown issues (strangely, export JPACKAGE_HOME still cause some jpackageHome not defined problem?)
# sudo nano org.mbari.vars.ui/build.gradle
# jpackageHome = "/usr/lib/jvm/openjdk-14" //System.getenv("JPACKAGE_HOME")
# and comment
# /*
# tasks.jpackageImage.doLast {
# ...
#} */
sudo ./build.sh
# ------------- BUT! Need other components e.g. vars-user-server but cannot compile yet ----

# 20210406 upgrade biigle to newest # https://biigle-admin-documentation.readthedocs.io/maintenance/
# but need git stash for modified build.sh, build.dockerfile docker-compose.yaml
sudo git stash
# sudo git remote add upstream https://github.com/biigle/biigle.git 
sudo git pull upstream master
# check new and backup uild.sh, build.dockerfile docker-compose.yaml
sudo git stash pop # Note! it's merge!

# Add MAIA in modules to build
# build.dockerfile
#        biigle/maia:${MAIA_VERSION} \
#
# && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Maia\\MaiaServiceProvider::class,' config/app.php
# build/config/filesystems.php

```
        // MAIA_TRAINING_PROPOSAL_STORAGE_DISK
        'maia-tp' => [
            'driver' => 'local',
            'root' => storage_path('app/public/maia-tp-patches'),
            'url' => env('APP_URL').'/storage/maia-tp-patches',
            'visibility' => 'public',
        ],
        // MAIA_ANNOTATION_CANDIDATE_STORAGE_DISK
        'maia-ac' => [
            'driver' => 'local',
            'root' => storage_path('app/public/maia-ac-patches'),
            'url' => env('APP_URL').'/storage/maia-ac-patches',
            'visibility' => 'public',
        ],
```
# and create corresponding directories: under /opt/biigle
# sudo mkdir storage/app/public/maia-tp-patches;  sudo mkdir storage/app/public/maia-ac-patches
# sudo chown -R biigle:biigle storage/app/public/maia-*-patches
# build.sh
#     --build-arg MAIA_VERSION="^1.17.6" \
# build/.env
MAIA_TRAINING_PROPOSAL_STORAGE_DISK=maia-tp
MAIA_ANNOTATION_CANDIDATE_STORAGE_DISK=maia-ac

# Allow new user to sign-up # https://github.com/biigle/core/discussions/338
BIIGLE_USER_REGISTRATION=true

# No need (MAIA is a biigle module that can be added by just edit build.sh/build.dockerfile)
# ==================================================================
## biigle/maia https://biigle.de/manual/tutorials/maia/about 
## biigle/maia[v1.17.0, ..., v1.17.6] require biigle/largo ^2.4
## biigle/largo[v2.4.0, ..., v2.22.1] require ext-vips *
## Install ext-vips
# sudo apt install libvips-dev
# sudo apt install php-dev php-pear
# sudo pecl install vips
## upgrade php >= 7.1
# sudo apt install php7.4-vips
## composer require jcupitt/vips #unsure it's needed or not: https://packagist.org/packages/jcupitt/vips
## But composer is needed, follow this: # https://www.dhttps://raw.githubusercontent.com/biigle/maia/master/requirements.txtigitalocean.com/community/tutorials/how-to-install-and-use-composer-on-ubuntu-16-04
# composer require biigle/maia
## then follow github: # https://github.com/biigle/maia
## wget https://raw.githubusercontent.com/biigle/maia/master/requirements.txt
## upgrade pip to v20.3.4 (< 21, must, otherwise drop support for python2.7). sudo apt remove python-pip
## sudo apt remove python3-pip && sudo python3.8 -m easy_install pip #will install pip 21.0.1 however
## sudo easy_install pip==20.3.4 # pip install --upgrade setuptools # <--- not really solve installaton problem
# curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
# python3 get-pip.py --force-reinstall
# sudo ln -s ~/.local/bin/pip3 /usr/bin/pip3
# python -m pip install -U setuptools
# python -m pip install -r requirements.txt












