import { Request, Response, NextFunction } from "express";
import { CategoriaModel } from "../models/categoriaModels";

// Crear una nueva categoría
export const crearCategoria = async (req: Request, res: Response) => {
  try {
    const categoria = await CategoriaModel.crear(req.body);
    res.status(201).json(categoria);
  } catch (error) {
    res.status(500).json({ message: "Error al crear la categoría", error });
  }
};

// Obtener todas las categorías
export const obtenerCategorias = async (req: Request, res: Response) => {
  try {
    const categorias = await CategoriaModel.obtenerTodas();
    res.status(200).json(categorias);
  } catch (error) {
    res.status(500).json({ message: "Error al obtener las categorías", error });
  }
};

// Obtener una categoría por ID
export const obtenerCategoriaById = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const categoria = await CategoriaModel.obtenerPorId(req.params.id);
    res.status(200).json(categoria);
  } catch (error) {
    next(error);
  }
};

// Actualizar una categoría por ID
export const actualizarCategoria = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const categoria = await CategoriaModel.actualizar(req.params.id, req.body);
    res.status(200).json(categoria);
  } catch (error) {
    next(error);
  }
};

// Eliminar una categoría por ID
export const eliminarCategoria = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    await CategoriaModel.eliminar(req.params.id);
    res.status(200).json({ message: "Categoría eliminada correctamente" });
  } catch (error) {
    next(error);
  }
};
