FROM golang:1.23.4-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git
COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o blog-server .
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata wget
RUN adduser -D -s /bin/sh bloguser
WORKDIR /app
COPY --from=builder /app/blog-server .
COPY --from=builder /app/docs ./docs
COPY --from=builder /app/public ./public
COPY --from=builder /app/templates ./templates
RUN chown -R bloguser:bloguser /app
USER bloguser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/ || exit 1
CMD ["./blog-server"]