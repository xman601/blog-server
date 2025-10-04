FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o blog-server .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/blog-server .
COPY --from=builder /app/public ./public
COPY --from=builder /app/templates ./templates
COPY --from=builder /app/docs ./docs
EXPOSE 8000
CMD ["./blog-server"]
