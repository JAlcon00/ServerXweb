import { ObjectId } from 'mongodb';
import { getArticulosCollection } from '../config/db';

// Interfaz para el modelo de Artículo
export interface IArticulo {
    _id?: ObjectId;
    nombre: string;
    descripcion: string;
    precio: number;
    stock: number;
    categoria: ObjectId;
    imagenUrl?: string;
    fechaCreacion: Date;
    activo: boolean;
}

export class ArticuloModel {
    // Crear un nuevo artículo
    static async crear(articulo: Omit<IArticulo, '_id'>): Promise<IArticulo> {
        const collection = await getArticulosCollection();
        const resultado = await collection.insertOne({
            ...articulo,
            fechaCreacion: new Date(),
            activo: true
        });
        return { ...articulo, _id: resultado.insertedId } as IArticulo;
    }

    // Obtener todos los artículos
    static async obtenerTodos(): Promise<IArticulo[]> {
        const collection = await getArticulosCollection();
        return (await collection.find<IArticulo>({ activo: true }).toArray()) as IArticulo[];
    }

    // Obtener artículo por ID
    static async obtenerPorId(id: string): Promise<IArticulo | null> {
        const collection = await getArticulosCollection();
        return collection.findOne<IArticulo>({ _id: new ObjectId(id), activo: true });
    }

    // Actualizar artículo
    static async actualizar(id: string, articulo: Partial<IArticulo>): Promise<boolean> {
        const collection = await getArticulosCollection();
        const resultado = await collection.updateOne(
            { _id: new ObjectId(id) },
            { $set: articulo }
        );
        return resultado.modifiedCount > 0;
    }

    // Eliminar artículo (borrado lógico)
    static async eliminar(id: string): Promise<boolean> {
        const collection = await getArticulosCollection();
        const resultado = await collection.updateOne(
            { _id: new ObjectId(id) },
            { $set: { activo: false } }
        );
        return resultado.modifiedCount > 0;
    }

    // Buscar artículos por categoría
    static async buscarPorCategoria(categoriaId: string): Promise<IArticulo[]> {
        const collection = await getArticulosCollection();
        return (await collection.find<IArticulo>({
            categoria: new ObjectId(categoriaId),
            activo: true
        }).toArray()) as IArticulo[];
    }

    // Buscar artículos por nombre
    static async buscarPorNombre(nombre: string): Promise<IArticulo[]> {
        const collection = await getArticulosCollection();
        return (await collection.find<IArticulo>({
            nombre: { $regex: nombre, $options: 'i' },
            activo: true
        }).toArray()) as IArticulo[];
    }
}