import { ObjectId } from 'mongodb';
import { getPedidosCollection } from '../config/db';

// Interfaz para los detalles de cada artículo en el pedido
export interface IDetallePedido {
    articulo: ObjectId;
    cantidad: number;
    precioUnitario: number;
    subtotal: number;
}

// Interfaz para el modelo de Pedido
export interface IPedido {
    _id?: ObjectId;
    usuario: ObjectId;
    detalles: IDetallePedido[];
    total: number;
    estado: 'pendiente' | 'confirmado' | 'enviado' | 'entregado' | 'cancelado';
    direccionEntrega: string;
    fechaCreacion: Date;
    fechaActualizacion: Date;
    activo: boolean;
}

export class PedidoModel {
    // Crear un nuevo pedido
    static async crear(pedido: Omit<IPedido, '_id' | 'fechaCreacion' | 'fechaActualizacion' | 'activo'>): Promise<IPedido> {
        const collection = await getPedidosCollection();
        const nuevoPedido = {
            ...pedido,
            fechaCreacion: new Date(),
            fechaActualizacion: new Date(),
            activo: true
        };
        const resultado = await collection.insertOne(nuevoPedido);
        return { ...nuevoPedido, _id: resultado.insertedId } as IPedido;
    }

    // Obtener todos los pedidos
    static async obtenerTodos(): Promise<IPedido[]> {
        const collection = await getPedidosCollection();
        return collection.find<IPedido>({ activo: true }).toArray();
    }

    // Obtener pedido por ID
    static async obtenerPorId(id: string): Promise<IPedido | null> {
        const collection = await getPedidosCollection();
        return collection.findOne({ _id: new ObjectId(id), activo: true }) as Promise<IPedido | null>;
    }

    // Obtener pedidos por usuario
    static async obtenerPorUsuario(usuarioId: string): Promise<IPedido[]> {
        const collection = await getPedidosCollection();
        return collection.find<IPedido>({
            usuario: new ObjectId(usuarioId),
            activo: true
        }).toArray();
    }

    // Actualizar estado del pedido
    static async actualizarEstado(id: string, estado: IPedido['estado']): Promise<boolean> {
        const collection = await getPedidosCollection();
        const resultado = await collection.updateOne(
            { _id: new ObjectId(id) },
            { 
                $set: { 
                    estado,
                    fechaActualizacion: new Date()
                }
            }
        );
        return resultado.modifiedCount > 0;
    }

    // Cancelar pedido
    static async cancelar(id: string): Promise<boolean> {
        return this.actualizarEstado(id, 'cancelado');
    }

    // Actualizar pedido
    static async actualizar(id: string, pedido: Partial<IPedido>): Promise<boolean> {
        const collection = await getPedidosCollection();
        const resultado = await collection.updateOne(
            { _id: new ObjectId(id) },
            { 
                $set: {
                    ...pedido,
                    fechaActualizacion: new Date()
                }
            }
        );
        return resultado.modifiedCount > 0;
    }

    // Eliminar pedido (borrado lógico)
    static async eliminar(id: string): Promise<boolean> {
        const collection = await getPedidosCollection();
        const resultado = await collection.updateOne(
            { _id: new ObjectId(id) },
            { $set: { activo: false, fechaActualizacion: new Date() } }
        );
        return resultado.modifiedCount > 0;
    }
}