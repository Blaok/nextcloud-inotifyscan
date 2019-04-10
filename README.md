# nextcloud-inotifyscan

Automatically scan external changes for [Nextcloud](https://nextcloud.com/) local storage.

## Motivation

Nextcloud uses a database to keep track of the files it stores. However, if a file is externally modified, the database won't know. It seems that the only possible way to inform the database is to run `occ files:scan`, which can be time- and resource-consuming if the whole storage is periodically scanned.

This Python script uses `inotifywait` to watch for changes and issues scan requests for the modified part on demand.

## Requirements

+ Linux with systemd
+ Nextcloud 14+ installation
+ `php` and `inotifywait` in `PATH`
+ Python 2.7 or 3.2+ as `/usr/bin/python`

The script should work if modified for other environments.

## Usage

1. Clone this repo: `git clone https://github.com/Blaok/nextcloud-inotifyscan; cd nextcloud-inotifyscan`
2. Install the script and config in the correct locations: `sudo make install`
3. Figure out which Unix `username` is running Nextcloud; on `Debian/Ubuntu` this is usually `www-data`
4. Create `/etc/nextcloud-inotifyscan/username.ini` according to the example given in `/etc/nextcloud-inotifyscan/sample.ini`
5. Enable and start the service: `sudo systemctl enable --now nextcloud-inotifyscan@username`

## Features

+ The `data` dir path is now read from `/path/to/nextcloud/config.php` automatically.

## Notes

+ This script is tested on Ubuntu 18.04 LTS
  - To install `inotifywait` on Ubuntu, use `sudo apt install inotify-tools`
+ This script ignores hidden files (`inotifywait --exclude '/\.'`), as Nextcloud does
+ A similar project implemented in `php`, [files_inotify](https://github.com/icewind1991/files_inotify),<del> doesn't seem to work at this point in time</del> exists but I'm not sure if it works
+ Watching ~2000 directories with ~30000 files, `inotifywait` consumes less than 4MB memory (RES+SHR)
+ To watch more than 8192 directories, `fs.inotify.max_user_watches` may need to be increased via `sysctl`
+ Nextcloud 14+ is required for [the `--shallow` flag](https://github.com/nextcloud/server/pull/9526)
