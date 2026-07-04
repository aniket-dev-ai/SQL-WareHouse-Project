
import os
from dotenv import load_dotenv
import psycopg

load_dotenv()  

conn = psycopg.connect(os.environ["SUPABASE_DATABASE_URL"])  
 
conn.autocommit = True
 