FROM node:12

WORKDIR /opt

COPY src/package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD [ "node", "src/app.js" ]

