install:
	install -m 755 nextcloud-inotifyscan /usr/local/bin/
	install -m 644 nextcloud-inotifyscan@.service /etc/systemd/system/
	mkdir -p /etc/nextcloud-inotifyscan/
	install -m 644 sample.ini /etc/nextcloud-inotifyscan/

uninstall:
	rm -f /usr/local/bin/nextcloud-inotifyscan \
	  /etc/systemd/system/nextcloud-inotifyscan@.service \
	  /etc/nextcloud-inotifyscan/sample.ini; \
	rmdir /etc/nextcloud-inotifyscan/; \
	exit 0
