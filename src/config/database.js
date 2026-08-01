const mariadb = require('mariadb');
const {db} = require('./env');
const pool = mariadb.createPool({...db, acquireTimeout:10000, bigIntAsNumber:true});
async function query(sql, params=[]) { let connection; try { connection=await pool.getConnection(); return await connection.query(sql,params); } finally { if(connection) connection.release(); } }
module.exports={pool,query};
