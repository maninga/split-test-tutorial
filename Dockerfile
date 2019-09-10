# start first stage build
FROM node:10-alpine as build
# The AS directive. This signals that this is not the final stage of the
# Dockerfile. Later on we can COPY artifacts out of this stage into our final
# container.

# For complication’s sake, let’s say we are using a library which requires
# node-gyp to install dependencies properly because it needs to compile native
# c++ binaries for the OS you are running on. In most cases you won’t need this,
# but some popular libraries, like redis require it.

# optionally install gyp tools
#RUN apk add --update --no-cache \
#    python \
#    make \
#    g++

# we are ADDing our source code into the container, to a folder called /src
ADD . /src
# we are changing our WORKDIR to that /src directory which now contains our code
WORKDIR /src
# running the appropriate npm script to install dependencies
RUN npm install
# running the appropriate npm script to lint our code
#RUN npm run lint
# running the appropriate npm script to test our code
#RUN npm run test
# running the appropriate npm script to compile our code with build
RUN npm run build
# removing devDependencies
RUN npm prune --production

# first stage build done ...

# start second stage build

FROM node:10-alpine

# install curl for healthcheck
RUN apk add --update --no-cache curl

ENV PORT=3000
EXPOSE $PORT

ENV DIR=/usr/src/service
WORKDIR $DIR

# Copy files from build stage
COPY --from=build /src/package.json package.json
COPY --from=build /src/package-lock.json package-lock.json
COPY --from=build /src/node_modules node_modules
COPY --from=build /src/.next .next

HEALTHCHECK --interval=5s \
            --timeout=5s \
            --retries=6 \
            CMD curl -fs http://localhost:$PORT/_health || exit 1

CMD ["node", "node_modules/.bin/next", "start"]

# second stage build done.
