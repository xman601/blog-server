FROM golang:1-alpine

RUN apk add --no-cache git tzdata wget

WORKDIR /app

RUN adduser -D -s /bin/sh bloguser
RUN chown -R bloguser:bloguser /app

USER bloguser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/ || exit 1

CMD ["go", "run", "main.go"]