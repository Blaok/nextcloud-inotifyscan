# nextcloud-inotifyscan

Automatically scan changes for [Nextcloud](https://nextcloud.com/) external storage.

## Motivation

Nextcloud uses a database to keep track of the files it stores. However, if a file is externally modified, the database won't know. It seems that the only possible way to inform the database is to run `occ files:scan`, which can be time- and resource-consuming if the whole storage is periodically scanned.

This Python script uses `inotifywait` to watch for changes and issues scan requests for the modified part on demand.

## Requirements

+ Linux with systemd
+ Nextcloud installation
+ `php` and `inotifywait` in `PATH`
+ `/usr/bin/python`

The script should work if modified for other environments.

## Usage

1. Download [nextcloud-inotifyscan](nextcloud-inotifyscan) as `/usr/local/bin/nextcloud-inotifyscan`
2. `sudo chmod +x /usr/local/bin/nextcloud-inotifyscan`
3. Download [nextcloud-inotifyscan.service](nextcloud-inotifyscan.service) as `/etc/systemd/system/nextcloud-inotifyscan.service`
4. Modify `NEXTCLOUD_HOME` and `USER_NAME` in `/etc/systemd/system/nextcloud-inotifyscan.service`
5. `sudo systemctl enable --now nextcloud-inotifyscan`

## Notes

+ This script is tested on Ubuntu 16.04 LTS and Ubuntu 18.04 LTS
  - To install `inotifywait` on Ubuntu, use `sudo apt install inotify-tools`
+ This script ignores hidden files (`inotifywait --exclude '/\.'`), as Nextcloud does
+ A similar project implemented in `php`, [files_inotify](https://github.com/icewind1991/files_inotify),<del> doesn't seem to work at this point in time</del> exists but I'm not sure if it works
+ Watching ~2000 directories with ~30000 files, `inotifywait` consumes less than 4MB memory (RES+SHR)
+ To watch more than 8192 directories, `fs.inotify.max_user_watches` may need to be increased via `sysctl`
+ Nextcloud 14 or a later version is required for [the `--shallow` flag](https://github.com/nextcloud/server/pull/9526)
