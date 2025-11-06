#FROM node:12
#COPY nodeapp /nodeapp
#WORKDIR /nodeapp
#RUN npm install
#CMD ["node", "/nodeapp/app.js"]


# Use a lightweight Node image
FROM node:18-alpine

# Set working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first (for caching)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the app
COPY . .

# Expose the port the app runs on
EXPOSE 3000

# Start the app
CMD ["node", "app.js"]

