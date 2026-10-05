FROM node:20-alpine
WORKDIR /app
COPY server.js .
COPY public ./public
RUN mkdir -p /app/data
EXPOSE 8765
CMD ["node", "server.js"]
