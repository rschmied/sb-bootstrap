# README
These files are required to boot a VIRL instance in the cloud. Bootstrapping a VIRL instance won't work without a valid private key for the Salt minion which is not included here.

See the LICENSE.TXT for licensing information.

# Files
Here's a list of the important files and what they do.

* `boot-data/boot.sh` Sample script that shows how to boot the instance passing the user-data and the meta-data to the instance.
* `boot-data/user-data` Cloud-init file passed into nova that contains a few files that are placed into the newly created instance. The Salt ID and the Salt domain need to be adapted. The private key file name must match the Salt ID and Salt domain. The extra.conf data must match the key / key file.
* `etc/virl.ini` is the virl.ini file that will be placed into the instance. The content is pretty much static, it should use dummy interfaces.
* `etc/common.sh` contains config variables and common stuff for the install scripts.
* `install.sh` is the main install script. It executes all additional scripts in the stages directory. It will reboot the instance after a stage has been finished and the exit value of that state is 1 (0 will not reboot the instance and continue with the next stage).
* `stages` Directory that contains the various stages that install the required packages and images.
* `born.py` extracts the instance create time from Cloud-Init using meta data that has been created during the 'nova boot' call.
* `reset.sh` is for testing, it will reset all stages to initial state (e.g. they will have the 'done-' prefix removed).
