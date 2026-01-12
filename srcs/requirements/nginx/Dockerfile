FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
