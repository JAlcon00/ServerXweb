import { MongoClient } from 'mongodb';
import dotenv from 'dotenv';

dotenv.config();

const user = process.env.user;
const password = process.env.password;
const cluster = process.env.cluster;
const dbName = process.env.dbname;

// db.ts
const url = `mongodb+srv://${user}:${password}@${cluster}.uoxe6ek.mongodb.net/${dbName}?retryWrites=true&w=majority&tls=true&tlsInsecure=true`;

class DatabaseConnection {
    private static instance: MongoClient | null;

    static async getInstance(): Promise<MongoClient> {
        if (!this.instance) {
            try {
                this.instance = await MongoClient.connect(url, {
                    maxPoolSize: 50,
                    connectTimeoutMS: 10000,
                    // Configuración SSL actualizada
                    ssl: true,
                    tls: true,
                    tlsInsecure: true,
                    serverApi: {
                        version: '1',
                        strict: true,
                        deprecationErrors: true
                    }
                });
                console.log('Connected successfully to MongoDB');
            } catch (error) {
                console.error('Error connecting to MongoDB:', error);
                throw error;
            }
        }
        return this.instance;
    }


    static async getCollection(collectionName: string) {
        const client = await this.getInstance();
        const db = client.db(dbName);
        return db.collection(collectionName);
    }

    static async closeConnection() {
        if (this.instance) {
            await this.instance.close();
            this.instance = null;
            console.log('Database connection closed');
        }
    }
}

// Export collections
export const getUsuariosCollection = () => DatabaseConnection.getCollection('Usuario');
export const getArticulosCollection = () => DatabaseConnection.getCollection('Articulo');
export const getPedidosCollection = () => DatabaseConnection.getCollection('Pedido');
export const getCategoriasCollection = () => DatabaseConnection.getCollection('Categoria');

export default DatabaseConnection;