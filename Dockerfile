FROM node:18-bullseye-slim
WORKDIR /app
COPY package.json .
COPY index.js .
COPY prisma ./prisma
COPY .env .env
RUN apt-get update \
	&& apt-get install -y wget --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& npm install --production
EXPOSE 3000
CMD ["npm", "start"]
