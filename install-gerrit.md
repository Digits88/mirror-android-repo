Install - Gerrit Method
=======================

DISCLAIMER
==========
This is still experimental and being reviewed! Proceed at your own risk!

Trackbacks
----------

+ https://help.ubuntu.com/10.04/serverguide/mysql.html
+ http://gerrit.googlecode.com/svn/documentation/2.2.1/install.html
+ http://source.android.com/source/using-repo.html

About
-----
This was all done on a nearly clean Ubuntu 10.04 LTS VM. Also, perhaps you should start screen now if you're connected via ssh.

    $ screen

Download and install software
-----------------------------

Also, verify MySQL automatically started

    $ sudo apt-get install git-core mysql-server openjdk-6-jre
    $ wget https://dl-ssl.google.com/dl/googlesource/git-repo/repo -O /usr/bin/repo
    $ sudo netstat -tap | grep mysqudo netstat -tap | grep mysql
    tcp        0      0 localhost:mysql         *:*                     LISTEN      5136/mysqld 

Prepare Gerrit
--------------

Create a Unix account for Gerrit and change to it's shell.

    $ sudo adduser --system --shell /bin/bash --gecos 'Gerrit Code Review User' --group --disabled-password --home /home/gerrit2 gerrit2
    $ sudo su gerrit2
    gerrit2 $ cd ~

Make a directory for Android's source and initialize and sync the mirror. Lower the jobs used if you don't have bandwidth to spare.

    gerrit2 $ mkdir android && cd android

    gerrit2 $ repo init -u https://android.googlesource.com/mirror/manifest --mirror
    repo mirror initialized in /home/gerrit2/androidtest

    gerrit2 $ repo sync -j 40
    Fetching projects: 100% (388/388), done.

Crease a Gerrit specific user within MySQL and give it full rights. Replace <gerritPW> appropriately.

    $ mysql -u root -p
    mysql> CREATE USER 'gerrit2'@'localhost' IDENTIFIED BY '<gerritPW>';
    mysql> CREATE DATABASE reviewdb;
    mysql> ALTER DATABASE reviewdb charset=latin1;
    mysql> GRANT ALL ON reviewdb.* TO 'gerrit2'@'localhost';
    mysql> FLUSH PRIVILEGES;

Download the latest version of Gerrit from http://code.google.com/p/gerrit/downloads/list

    gerrit2 $ cd ~
    gerrit2 $ wget http://gerrit.googlecode.com/files/gerrit-2.4.2.war -O gerrit.war

Download and install the OpenJDK jre and initialize the site directory. For this, gmail was used as the SMTP server.

    gerrit2 $ java -jar gerrit.war init -d review_site
    Create '/home/gerrit2/review_site' [Y/n]? <Enter>
    Location of Git repositories [git]: <Enter>

    # Database
    Database server type [H2/?]: MySQL
    Gerrit Code Review is not shipped with MySQL.
    Download and install it now [Y/n]? Y
    Server hostname [localhost]: <Enter>
    Server port [(MYSQL default)]: <Enter>
    Database name [reviewdb]: <Enter>
    Database username [gerrit2]: <Enter>
    gerrit2's password: <gerritPW>

    # Authentication
    Authentication method [OPENID/?]:<Enter>

    SMTP server hostname [localhost]: smtp.google.com
    SMTP server port [(default)]: 465
    SMTP encryption [NONE/?]: SSL
    SMTP username [gerrit2]: <user@gmail.com>
    password: <gmailPW>

    # Process
    Run as [gerrit2]: <Enter>
    Java runtime [/usr/lib/jvm/java-6-openjdk/jre]: <Enter>
    Copy gerrit.war [Y/n]? Y
    
    # SSH Daemon
    Listen on address [*]: <Enter>
    Listen on port [29418]: 2323 (Or another port <sshPort>, referred to later)

    Download and install Bouncy Castle Crypto [Y/n]? Y

    # HTTP Daemon
    Behind reverse proxy [y/N]? N
    Use SSL [y/N]? N
    Listen on address [*]: <Enter>
    Listen on port [8080]: 8888 (Or another port <webPort>, referred to later)
    Canonical URL [<url>]: http://<site.com>:<port>

    Initialized /home/gerrit2/review_site
    Executing /home/gerrit2/review_site/bin/gerrit.sh start
    Starting Gerrit Code Review: OK

If Gerrit doesn't automatically start, go into the site directory and start it manually.

    gerrit2 $ cd review_site
    gerrit2 $ ./bin/gerrit.sh start
    Starting Gerrit Code Review: OK

(Optional) Delete the war file that was copied to the site directory.

    gerrit2  $ rm ~gerrit2/gerrit.war

Configure Gerrit
----------------
Load the site in a browser and register an account. The first user to register an account is automatically placed into the Administrators group. Add your public key to the account. Also, add the public key of the gerrit2 account for adding Android to the repo.

Create a new group with the name 'android' through Gerrit's web interface.

**NOTE** I am very new to both Gerrit and git and would like feedback on the security of doing this. (Feedback on anything else would be appreciated, too) I only want specified users put in the android groud to read and commit.

Go to Projects->All-Projects and replace every instance of the Registered Users or Anonymous Users groups with android. 

Create a new reference to /refs/tags/* and then add Create Refrerence to /refs/heads/* and /refs/tags* with android as the group. Add the following permissions to /refs/* and add android as the group

+ Read 
+ Create Reference 
+ Forge Author Identity 
+ Forge Committer Identity 
+ Push 
+ Force Push
+ Push Annotated Tag
+ Push Merge Commit 

Add Android to Gerrit
---------------------
Verify that everything is working thus far by accessing your Gerrit server via ssh:

    gerrit2 $ ssh -p <gerritPort> <gerritName>@<serverName>

    ****    Welcome to Gerrit Code Review    ****
    Hi Brandon Amos, you have successfully connected over SSH.

Go back to $ANDROID\_ROOT and add the projects and push the data to Gerrit. $REPO_PATH will be dynamically set when executing `repo -forall`. Single quotes are important here. Also note that <sshPort> is the ssh port of the internal daemon running within Gerrit, not the regular ssh port.

    gerrit2 $ repo forall -c 'echo $REPO_PATH; ssh -p <sshPort> <gerritUser>@<site.com> gerrit create-project --name android/$REPO_PATH --owner android;' 
    gerrit2 $ repo forall -c 'echo $REPO_PATH; git push ssh://<gerritUser@<site.com>:<sshPort>/android/$REPO_PATH +refs/heads/* +refs/tags/*;' 

Final Steps
-----------
Exit the gerrit2 account and make the Gerrit daemon start on boot

    gerrit2 $ exit
    $ sudo ln -snf ~gerrit/review_site/bin/gerrit.sh /etc/init.d/gerrit.sh
    $ sudo ln -snf /etc/init.d/gerrit.sh /etc/rc3.d/S90gerrit

Client Steps
------------
After verifying that a user and public key exist on Gerrit, make a new directory for the source and initialize and sync the repo.

    $ mkdir android-source
    $ repo init -u ssh<gerritUser>@<site.com>:<sshPort>/android/platform/manifest
    $ repo sync -j 40
