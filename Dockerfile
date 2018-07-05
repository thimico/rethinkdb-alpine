FROM alpine:3.6

RUN apk add --update rethinkdb && rm -rf /var/cache/apk/*

WORKDIR /data

CMD ["rethinkdb", "--bind", "all"]

# process cluster webui
EXPOSE 28015 29015 8080