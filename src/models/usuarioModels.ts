import { ObjectId } from 'mongodb';
import { getUsuariosCollection } from '../config/db';
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12; 

// Interfaz para el modelo de Usuario
export interface IUsuario {
    _id?: ObjectId;
    nombre: string;
    email: string;
    password: string;
    direccion: string;
    telefono: string;
    rol: 'cliente' | 'admin';
    fechaCreacion: Date;
    activo: boolean;
}

export class UsuarioModel {
    // Crear un nuevo usuario
    static async crear(usuario: Omit<IUsuario, '_id' | 'fechaCreacion' | 'activo'>): Promise<IUsuario> {
        const collection = await getUsuariosCollection();
        
        // Verificar si el email ya existe
        const existeEmail = await collection.findOne({ email: usuario.email });
        if (existeEmail) {
            throw new Error('El email ya está registrado');
        }

        // Encriptar contraseña
        const hashPassword = await bcrypt.hash(usuario.password, SALT_ROUNDS);
        
        const nuevoUsuario = {
            ...usuario,
            password: hashPassword,
            fechaCreacion: new Date(),
            activo: true
        };
        
        const resultado = await collection.insertOne(nuevoUsuario);
        return { ...nuevoUsuario, _id: resultado.insertedId } as IUsuario;
    }

    // Obtener todos los usuarios activos
    static async obtenerTodos(): Promise<IUsuario[]> {
        const collection = await getUsuariosCollection();
        return collection.find<IUsuario>({ activo: true }).toArray();
    }

    // Obtener usuario por ID
    static async obtenerPorId(id: string): Promise<IUsuario | null> {
        const collection = await getUsuariosCollection();
        try {
            return collection.findOne({ 
                _id: new ObjectId(id), 
                activo: true 
            }) as Promise<IUsuario | null>;
        } catch (error) {
            throw new Error('ID de usuario inválido');
        }
    }

    // Obtener usuario por email
    static async obtenerPorEmail(email: string): Promise<IUsuario | null> {
        const collection = await getUsuariosCollection();
        return collection.findOne({ 
            email, 
            activo: true 
        }) as Promise<IUsuario | null>;
    }

    // Validar credenciales para login
    static async validarCredenciales(email: string, password: string): Promise<IUsuario | null> {
        const usuario = await this.obtenerPorEmail(email);
        if (!usuario) return null;

        const passwordValida = await bcrypt.compare(password, usuario.password);
        return passwordValida ? usuario : null;
    }

    // Actualizar usuario
    static async actualizar(id: string, usuario: Partial<IUsuario>): Promise<boolean> {
        const collection = await getUsuariosCollection();
        
        // Si se actualiza el email, verificar que no exista
        if (usuario.email) {
            const existeEmail = await collection.findOne({
                email: usuario.email,
                _id: { $ne: new ObjectId(id) }
            });
            if (existeEmail) {
                throw new Error('El email ya está registrado');
            }
        }
        
        // Si se actualiza la contraseña, encriptarla
        if (usuario.password) {
            usuario.password = await bcrypt.hash(usuario.password, SALT_ROUNDS);
        }

        const resultado = await collection.updateOne(
            { _id: new ObjectId(id) },
            { $set: usuario }
        );
        return resultado.modifiedCount > 0;
    }

    // Eliminar usuario (borrado lógico)
    static async eliminar(id: string): Promise<boolean> {
        const collection = await getUsuariosCollection();
        const resultado = await collection.updateOne(
            { _id: new ObjectId(id) },
            { $set: { activo: false } }
        );
        return resultado.modifiedCount > 0;
    }

    // Cambiar contraseña
    static async cambiarPassword(id: string, nuevaPassword: string): Promise<boolean> {
        const hashPassword = await bcrypt.hash(nuevaPassword, SALT_ROUNDS);
        return this.actualizar(id, { password: hashPassword });
    }

    // Buscar usuarios por rol
    static async buscarPorRol(rol: 'cliente' | 'admin'): Promise<IUsuario[]> {
        const collection = await getUsuariosCollection();
        return collection.find<IUsuario>({ 
            rol, 
            activo: true 
        }).toArray();
    }

    // Buscar usuarios por nombre
    static async buscarPorNombre(nombre: string): Promise<IUsuario[]> {
        const collection = await getUsuariosCollection();
        return collection.find<IUsuario>({
            nombre: { $regex: nombre, $options: 'i' },
            activo: true
        }).toArray();
    }
}