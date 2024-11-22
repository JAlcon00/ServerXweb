import { Router } from "express";
import {
    crearPedido,
    obtenerPedidos,
    obtenerPedidoById,
    obtenerPedidosPorUsuario,
    actualizarEstadoPedido,
    cancelarPedido,
    actualizarPedido,
    eliminarPedido
} from '../controllers/pedidoController';

const router = Router();

router.post('/', crearPedido);
router.get('/', obtenerPedidos);
router.get('/:id', obtenerPedidoById);
router.get('/usuario/:usuarioId', obtenerPedidosPorUsuario);
router.put('/:id/estado', actualizarEstadoPedido);
router.put('/:id', actualizarPedido);
router.delete('/:id', eliminarPedido);
router.post('/:id/cancelar', cancelarPedido);

export default router;