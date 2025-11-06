#FROM node:12
#COPY nodeapp /nodeapp
#WORKDIR /nodeapp
#RUN npm install
#CMD ["node", "/nodeapp/app.js"]



# Use a lightweight Node.js base image
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy all your code into the container
COPY ./nodeapp/ ./

# Install only production dependencies
RUN npm install --production

# Expose the port your app runs on
EXPOSE 3000

# Start the application
CMD ["node", "app.js"]
