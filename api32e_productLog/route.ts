import { NextResponse } from "next/server";
import { Pool } from "pg";
import { db } from "@/lib/db.server";
import { v4 as uuidv4 } from "uuid";

const pool = new Pool({ ...db.json.pool.options, database: "eip_normalized_db" });

// Napló bejegyzések típusa
export interface ProductLogEntry {
  id?: string;
  fieldName: string;
  oldValue: string;
  newValue: string;
  action: 'confirm' | 'modify' | 'delete' | 'reset';
  timestamp: Date;
  userId: string;
  productId?: string;
  imageId?: string;
}

// Napló bejegyzések lekérése
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const imageId = searchParams.get("imageId");
  const productId = searchParams.get("productId");
  
  if (!imageId && !productId) {
    return NextResponse.json({ error: "Either imageId or productId is required" }, { status: 400 });
  }
  
  const client = await pool.connect();
  
  try {
    // Ellenőrizzük, hogy létezik-e a napló tábla
    const tableExists = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 't34_fieldlogs'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      return NextResponse.json({
        logs: [],
        success: true
      });
    }
    
    // Lekérési feltételek összeállítása
    let query = `
      SELECT 
        log_id,
        field_name,
        old_value,
        new_value,
        action,
        timestamp,
        user_id,
        product_id,
        image_id
      FROM t34_fieldlogs
      WHERE 1=1
    `;
    
    const params: any[] = [];
    
    if (imageId) {
      params.push(imageId);
      query += ` AND image_id = $${params.length}`;
    }
    
    if (productId) {
      params.push(productId);
      query += ` AND product_id = $${params.length}`;
    }
    
    query += ` ORDER BY timestamp DESC`;
    
    const result = await client.query(query, params);
    
    // Adatok formázása
    const logs: ProductLogEntry[] = result.rows.map(row => ({
      id: row.log_id,
      fieldName: row.field_name,
      oldValue: row.old_value,
      newValue: row.new_value,
      action: row.action,
      timestamp: row.timestamp,
      userId: row.user_id,
      productId: row.product_id,
      imageId: row.image_id
    }));
    
    return NextResponse.json({
      logs,
      success: true
    });
  } catch (error) {
    console.error("Error fetching product logs:", error);
    return NextResponse.json({
      error: "Failed to fetch product logs",
      details: error.message,
      success: false
    }, { status: 500 });
  } finally {
    client.release();
  }
}

// Napló bejegyzések felvétele
export async function POST(request: Request) {
  const client = await pool.connect();
  
  try {
    // Kérés tartalmának feldolgozása
    const { logs, imageId, productId } = await request.json();
    
    if (!logs || !Array.isArray(logs) || logs.length === 0) {
      return NextResponse.json({ error: "Logs array is required" }, { status: 400 });
    }
    
    if (!imageId && !productId) {
      return NextResponse.json({ error: "Either imageId or productId is required" }, { status: 400 });
    }
    
    await client.query("BEGIN");
    
    // Tábla létrehozása, ha még nem létezik
    await client.query(`
      CREATE TABLE IF NOT EXISTS t34_fieldlogs (
        log_id UUID PRIMARY KEY,
        field_name TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        action TEXT NOT NULL,
        timestamp TIMESTAMP NOT NULL,
        user_id TEXT NOT NULL,
        product_id UUID,
        image_id UUID,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Naplóbejegyzések mentése
    const insertedIds: string[] = [];
    
    for (const log of logs) {
      const logId = uuidv4();
      
      await client.query(`
        INSERT INTO t34_fieldlogs (
          log_id, field_name, old_value, new_value, 
          action, timestamp, user_id, product_id, image_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `, [
        logId,
        log.fieldName,
        log.oldValue || '',
        log.newValue || '',
        log.action,
        log.timestamp,
        log.userId,
        productId || null,
        imageId || null
      ]);
      
      insertedIds.push(logId);
    }
    
    await client.query("COMMIT");
    
    return NextResponse.json({
      success: true,
      insertedIds,
      message: `Successfully inserted ${insertedIds.length} log entries`
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error saving product logs:", error);
    
    return NextResponse.json({
      error: "Failed to save product logs",
      details: error.message,
      success: false
    }, { status: 500 });
  } finally {
    client.release();
  }
}
