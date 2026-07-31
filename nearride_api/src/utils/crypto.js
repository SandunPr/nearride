const crypto=require('crypto'); const {encryptionKey}=require('../config/env');
const key=crypto.createHash('sha256').update(encryptionKey).digest();
function encrypt(value){if(!value)return null;const iv=crypto.randomBytes(12),cipher=crypto.createCipheriv('aes-256-gcm',key,iv);const body=Buffer.concat([cipher.update(value,'utf8'),cipher.final()]);return [iv,cipher.getAuthTag(),body].map(x=>x.toString('base64url')).join('.');}
function mask(value){if(!value)return null;const clean=value.replace(/\s/g,'');return clean.length<5?'***':`${clean.slice(0,2)}***${clean.slice(-2)}`;}
module.exports={encrypt,mask};
