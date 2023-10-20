import { Pool } from 'pg';

export const database = new Pool({
  user: process.env.SUPABASE_USER,
  database: process.env.SUPABASE_DATABASE,
  password: process.env.SUPABASE_PASSWORD,
  port: parseInt(process.env.SUPABASE_PORT || '5432'),
  host: process.env.SUPABASE_HOST,
  max: 20,
});
