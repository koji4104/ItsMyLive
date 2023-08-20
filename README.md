# It's my Live

## :movie_camera: Features

**It's my Live** is a live distribution application.

## YouTube
<img src='img/3.png' width=50%>

Enter URL and KEY in App. Note that the KEY changes each time the button is pressed.

## AWS MediaLive

e.g. rtmp://xxxx/test/abcd
URL = rtmp://xxxx/test
KEY = abcd

## Nginx

start nginx
nginx -s quit

URL = rtmp://xxxx:1935/live
KEY = live

### Modify the conf file
vi /etc/nginx/nginx.conf

### Add the following
rtmp {
    server {
        listen 1935;
        chunk_size 4096;
        access_log /var/log/rtmp_access.log;
        application live { # name is live
            live on;
            record off;
        }
    }
}

ffmpeg -re -y -i "rtmp://localhost:1935/live/live" -movflags faststart -c copy C:\dev\tools\ffmpeg\rec.mp4

ffmpeg\ffplay -i "rtmp://localhost:1935/live/live?mode=listener"

ffplay -listen 1 -i rtmp://0.0.0.0:1935/s/streamKey

