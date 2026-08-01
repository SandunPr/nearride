const jwt=require('jsonwebtoken'),crypto=require('crypto'); const {jwt:cfg}=require('../config/env'); const {query}=require('../config/database');
const hash=t=>crypto.createHash('sha256').update(t).digest('hex');
function access(user){return jwt.sign({sub:user.public_id,isProvider:!!user.is_provider,isAdmin:!!user.is_admin},cfg.accessSecret,{expiresIn:cfg.accessExpires});}
async function session(user,device){const refresh=jwt.sign({sub:user.public_id,jti:crypto.randomUUID()},cfg.refreshSecret,{expiresIn:cfg.refreshExpires});await query('INSERT INTO refresh_tokens (user_id,token_hash,device_name,expires_at,created_at) VALUES (?,?,?,DATE_ADD(NOW(),INTERVAL 30 DAY),NOW())',[user.id,hash(refresh),device||null]);return {accessToken:access(user),refreshToken:refresh,tokenType:'Bearer',expiresIn:900};}
module.exports={hash,access,session};
