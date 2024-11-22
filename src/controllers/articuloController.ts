import { Request, Response, NextFunction } from "express";
import { ArticuloModel } from "../models/articuloModels";

// Crear un nuevo artículo
export const crearArticulo = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const articulo = await ArticuloModel.crear(req.body);
    res.status(201).json(articulo);
  } catch (error) {
    return next(error);
  }
};

// Obtener todos los artículos
export const obtenerArticulos = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const articulos = await ArticuloModel.obtenerTodos();
    res.status(200).json(articulos);
  } catch (error) {
    next(error);
  }
};

export const obtenerArticuloById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const articulo = await ArticuloModel.obtenerPorId(req.params.id);
    res.status(200).json(articulo);
  } catch (error) {
    next(error);
  }
  
}
// Actualizar un artículo por ID
export const actualizarArticulo = async ( req: Request, res: Response, next: NextFunction ) => {
  try {
    const articulo = await ArticuloModel.actualizar(req.params.id, req.body);
    res.status(200).json(articulo);
  } catch (error) {
    next(error);
  }
}
// Eliminar un artículo por ID
export const eliminarArticulo = async ( req: Request, res: Response, next: NextFunction ) => {
  try {
    await ArticuloModel.eliminar(req.params.id);
    res.status(204).json();
  } catch (error) {
    next(error);
  }
}

// Buscar artículos por categoría
export const buscarArticulosPorCategoria = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const articulos = await ArticuloModel.buscarPorCategoria(
      req.params.categoriaId
    );
    res.status(200).json(articulos);
  } catch (error) {
    next(error);
  }
};

// Buscar artículos por nombre
export const buscarArticulosPorNombre = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const articulos = await ArticuloModel.buscarPorNombre(
      req.query.nombre as string
    );
    res.status(200).json(articulos);
  } catch (error) {
    next(error);
  }
};
