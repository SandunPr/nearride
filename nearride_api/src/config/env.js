require('dotenv').config();
const required = ['DB_HOST','DB_NAME','DB_USER','DB_PASSWORD','JWT_ACCESS_SECRET','JWT_REFRESH_SECRET','REGISTRATION_ENCRYPTION_KEY'];
if (process.env.NODE_ENV === 'production') for (const key of required) if (!process.env[key]) throw new Error(`Missing environment variable: ${key}`);
module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development', port: Number(process.env.PORT || 3000), appName: process.env.APP_NAME || 'NearRide', appUrl: process.env.APP_URL || 'http://localhost:3000',
  db: {host:process.env.DB_HOST||'127.0.0.1',port:Number(process.env.DB_PORT||3306),database:process.env.DB_NAME||'nearride',user:process.env.DB_USER||'root',password:process.env.DB_PASSWORD||'',connectionLimit:Number(process.env.DB_CONNECTION_LIMIT||10)},
  jwt: {accessSecret:process.env.JWT_ACCESS_SECRET||'development-access-secret-change-me',refreshSecret:process.env.JWT_REFRESH_SECRET||'development-refresh-secret-change-me',accessExpires:process.env.JWT_ACCESS_EXPIRES_IN||'15m',refreshExpires:process.env.JWT_REFRESH_EXPIRES_IN||'30d'},
  googleClientId: process.env.GOOGLE_CLIENT_ID || '', uploadDir: process.env.UPLOAD_DIRECTORY || 'public/uploads', maxImages:Number(process.env.MAX_IMAGES_PER_LISTING||2), maxImageMb:Number(process.env.MAX_IMAGE_SIZE_MB||5), autoApprove:process.env.AUTO_APPROVE_LISTINGS==='true', defaultRadius:Number(process.env.DEFAULT_SEARCH_RADIUS_KM||25), corsOrigins:(process.env.CORS_ORIGINS||'').split(',').filter(Boolean), encryptionKey:process.env.REGISTRATION_ENCRYPTION_KEY||'development-key'
};
