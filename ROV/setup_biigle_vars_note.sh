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
# It strangly some uncetain bugs when add users using GUI interface


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

