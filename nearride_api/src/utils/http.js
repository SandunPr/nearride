const ok=(res,data,message='Request completed successfully.',meta)=>res.json({success:true,message,data,...(meta?{meta}:{})});
class AppError extends Error { constructor(status,message,code='REQUEST_ERROR',errors){super(message);this.status=status;this.code=code;this.errors=errors;} }
const asyncHandler=fn=>(req,res,next)=>Promise.resolve(fn(req,res,next)).catch(next);
module.exports={ok,AppError,asyncHandler};
