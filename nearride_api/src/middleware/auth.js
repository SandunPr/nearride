const jwt=require('jsonwebtoken'); const {jwt:cfg}=require('../config/env'); const {AppError}=require('../utils/http');
function auth(req,res,next){const token=req.headers.authorization?.replace(/^Bearer\s+/i,'');if(!token)return next(new AppError(401,'Authentication required.','UNAUTHENTICATED'));try{req.auth=jwt.verify(token,cfg.accessSecret);next();}catch{return next(new AppError(401,'Invalid or expired access token.','UNAUTHENTICATED'));}}
const admin=(req,res,next)=>req.auth?.isAdmin?next():next(new AppError(403,'Administrator access required.','FORBIDDEN'));
module.exports={auth,admin};
