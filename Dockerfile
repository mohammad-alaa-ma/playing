#FROM node:12
#COPY nodeapp /nodeapp
#WORKDIR /nodeapp
#RUN npm install
#CMD ["node", "/nodeapp/app.js"]


# Stage 1: build
FROM node:12-alpine AS build
WORKDIR /nodeapp
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: runtime
FROM node:12-alpine
WORKDIR /nodeapp
COPY --from=build /nodeapp .
CMD ["node", "app.js"]
