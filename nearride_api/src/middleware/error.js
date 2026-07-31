function notFound(req,res){res.status(404).json({success:false,message:'Route not found.',code:'NOT_FOUND'});}
function errorHandler(err,req,res,next){if(res.headersSent)return next(err);const status=err.status||500; if(status===500) console.error(err);res.status(status).json({success:false,message:status===500?'An unexpected error occurred.':err.message, ...(err.errors?{errors:err.errors}:{}),code:err.code||'INTERNAL_ERROR'});}
module.exports={notFound,errorHandler};
