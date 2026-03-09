# Cloud Run: serve index.html with API key from env
FROM node:20-alpine

WORKDIR /app

COPY server.js index.html ./

# Cloud Run sets PORT
ENV PORT=8080
EXPOSE 8080

CMD ["node", "server.js"]
