# **1. Development stage**
FROM node:18-alpine3.18 AS development

# Instalar dependências necessárias
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev nasm bash vips-dev git

# Definir o ambiente como desenvolvimento
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}

# Configurar o diretório de trabalho
WORKDIR /opt/
COPY package.json package-lock.json ./

# Instalar dependências
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install
ENV PATH=/opt/node_modules/.bin:$PATH

# Configurar diretório da aplicação
WORKDIR /opt/app
COPY . .
RUN chown -R node:node /opt/app

# Usar usuário não root
USER node

# Construir o projeto
RUN ["npm", "run", "build"]

# Expor a porta para desenvolvimento
EXPOSE 1337
CMD ["npm", "run", "develop"]

# **2. Production stage**
FROM node:18-alpine AS build

# Instalar apenas dependências necessárias para construir a aplicação
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git > /dev/null 2>&1

# Definir o ambiente como produção
ARG NODE_ENV=production
ENV NODE_ENV=production

# Configurar o diretório de trabalho
WORKDIR /opt/
COPY package.json package-lock.json ./

# Instalar dependências e construir o projeto
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm ci --production
ENV PATH=/opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY . .
RUN npm run build

# **3. Final production image**
FROM node:18-alpine AS production

# Instalar apenas o que é necessário para execução
RUN apk add --no-cache vips-dev

# Configurar o ambiente como produção
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Configurar o diretório de trabalho
WORKDIR /opt/
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./

# Definir o PATH
ENV PATH=/opt/node_modules/.bin:$PATH

# Usar usuário não root
RUN chown -R node:node /opt/app
USER node

# Expor a porta para produção
EXPOSE 1337
CMD ["npm", "run", "start"]
