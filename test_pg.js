const { Client } = require('pg');

async function test() {
  const client = new Client({
    connectionString: "postgresql://postgres:postgres@localhost:5432/postgres" // just a dummy, we won't connect, just want to check syntax if possible, but actually we can't test without a real db.
  });
}
test();
