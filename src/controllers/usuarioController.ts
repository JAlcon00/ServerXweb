import { Request, Response, NextFunction } from "express";
import { UsuarioModel } from "../models/usuarioModels";
import { loginLimiter } from "../middleware/rateLimiter";

// Crear un nuevo usuario
export const crearUsuario = async (req: Request, res: Response) => {
    try {
        console.log('Solicitud POST recibida para crear usuario:', req.body);
        const usuario = await UsuarioModel.crear(req.body);
        const { password, ...usuarioSinPassword } = usuario;
        res.status(201).json(usuarioSinPassword);
        console.log(`Usuario registrado exitosamente - ID: ${usuario._id}`);
    } catch (error) {
        if (
            error instanceof Error &&
            error.message === "El email ya está registrado"
        ) {
            console.log('Error: Email ya registrado');
            res.status(400).json({ message: error.message });
        } else {
            console.log('Error al crear usuario:', error);
            res.status(500).json({ message: "Error al crear el usuario", error });
        }
    }
};

// Obtener todos los usuarios
export const obtenerUsuarios = async (req: Request, res: Response) => {
  try {
    const usuarios = await UsuarioModel.obtenerTodos();
    const usuariosSinPassword = usuarios.map(({ password, ...rest }) => rest);
    res.status(200).json(usuariosSinPassword);
  } catch (error) {
    res.status(500).json({ message: "Error al obtener los usuarios", error });
  }
};

// Obtener un usuario por ID
export const obtenerUsuariobyId = async (req: Request, res: Response) => {
  try {
    const usuario = await UsuarioModel.obtenerPorId(req.params.id);
    if (usuario) {
      const { password, ...usuarioSinPassword } = usuario;
      res.status(200).json(usuarioSinPassword);
    } else {
      res.status(404).json({ message: "Usuario no encontrado" });
    }
  } catch (error) {
    if (error instanceof Error && error.message === "ID de usuario inválido") {
      res.status(400).json({ message: error.message });
    } else {
      res.status(500).json({ message: "Error al obtener el usuario", error });
    }
  }
};

// Actualizar un usuario
export const actualizarUsuario = async (req: Request, res: Response) => {
  try {
    const actualizado = await UsuarioModel.actualizar(req.params.id, req.body);
    if (actualizado) {
      const usuario = await UsuarioModel.obtenerPorId(req.params.id);
      const { password, ...usuarioSinPassword } = usuario!;
      res.status(200).json(usuarioSinPassword);
    } else {
      res.status(404).json({ message: "Usuario no encontrado" });
    }
  } catch (error) {
    if (
      error instanceof Error &&
      error.message === "El email ya está registrado"
    ) {
      res.status(400).json({ message: error.message });
    } else {
      res
        .status(500)
        .json({ message: "Error al actualizar el usuario", error });
    }
  }
};

// Eliminar un usuario
export const eliminarUsuario = async (req: Request, res: Response) => {
  try {
    const eliminado = await UsuarioModel.eliminar(req.params.id);
    if (eliminado) {
      res.status(200).json({ message: "Usuario eliminado con éxito" });
    } else {
      res.status(404).json({ message: "Usuario no encontrado" });
    }
  } catch (error) {
    res.status(500).json({ message: "Error al eliminar el usuario", error });
  }
};

// Login de usuario con rate limiting
export const loginUsuario = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { email, password } = req.body;
    !email || !password ? res.status(400).json({ message: "Email y password son requeridos" }) : null;

    const usuario = await UsuarioModel.validarCredenciales(email, password);
    if (usuario) {
      const { password, ...usuarioSinPassword } = usuario;
      res.status(200).json(usuarioSinPassword);
    } else {
      res.status(401).json({ message: "Credenciales inválidas" });
    }
  } catch (error) {
    res.status(500).json({ message: "Error en el login" });
  }
};

// Cambiar contraseña
export const cambiarPassword = async (req: Request, res: Response) => {
  try {
    const { nuevaPassword } = req.body;
    !nuevaPassword ? res.status(400).json({ message: "Nueva contraseña es requerida" }) : null;

    const actualizado = await UsuarioModel.cambiarPassword(
      req.params.id,
      nuevaPassword
    );
    if (actualizado) {
      res.status(200).json({ message: "Contraseña actualizada con éxito" });
    } else {
      res.status(404).json({ message: "Usuario no encontrado" });
    }
  } catch (error) {
    res.status(500).json({ message: "Error al cambiar la contraseña", error });
  }
};

// Buscar usuarios por rol
export const buscarUsuariosPorRol = async (req: Request, res: Response) => {
  try {
    const rol = req.params.rol as "cliente" | "admin";
    !["cliente", "admin"].includes(rol) ? res.status(400).json({ message: "Rol inválido" }) : null;

    const usuarios = await UsuarioModel.buscarPorRol(rol);
    const usuariosSinPassword = usuarios.map(({ password, ...rest }) => rest);
    res.status(200).json(usuariosSinPassword);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error al buscar usuarios por rol", error });
  }
};

// Buscar usuarios por nombre
export const buscarUsuariosPorNombre = async (req: Request, res: Response) => {
  try {
    const nombre = req.query.nombre as string;
    
    !nombre ? res.status(400).json({ message: "Nombre es requerido" }) : null;
    

    const usuarios = await UsuarioModel.buscarPorNombre(nombre);
    const usuariosSinPassword = usuarios.map(({ password, ...rest }) => rest);
    res.status(200).json(usuariosSinPassword);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error al buscar usuarios por nombre", error });
  }
};
