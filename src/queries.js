const Pool = require('pg').Pool
const pool = new Pool({
  user: process.env.POSTGRES_USER,
  host: process.env.POSTGRES_HOST,
  database: process.env.DATABASE,
  password: process.env.POSTGRES_PASSWORD,
  port: process.env.PORT,
})
const getHelloWordString = (request, response) => {
  pool.query('SELECT * FROM hello FETCH FIRST ROW ONLY', (error, results) => {
    if (error) {
      response.status(500).json({ message: "Something went wrong when retrieving data from db" })
    } else {
      var helloWord = results.rows[0].name;
      response.status(200).json(helloWord)
    }

  })
}
module.exports = {
  getHelloWordString
}
