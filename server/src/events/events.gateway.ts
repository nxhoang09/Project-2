import { WebSocketGateway, WebSocketServer, SubscribeMessage, MessageBody, ConnectedSocket } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({ cors: { origin: '*' } }) 
export class EventsGateway {
  @WebSocketServer()
  server!: Server;

  @SubscribeMessage('join_device_room')
  handleJoinRoom(@MessageBody() deviceId: string, @ConnectedSocket() client: Socket) {
    client.join(deviceId);
    console.log(`[Socket] Điện thoại ${client.id} đã vào phòng hóng tin của khóa: ${deviceId}`);
  }

  @SubscribeMessage('leave_device_room')
  handleLeaveRoom(@MessageBody() deviceId: string, @ConnectedSocket() client: Socket) {
    client.leave(deviceId);
    console.log(`[Socket] Điện thoại ${client.id} đã rời phòng của khóa: ${deviceId}`);
  }
  
  notifyNewAccessLog(deviceId: string, logData: any) {
    this.server.to(deviceId).emit('new_access_log', logData);
  }

  notifyDeviceStatus(deviceId: string, status: string) {
    this.server.to(deviceId).emit('device_status_changed', {deviceId, status});
  }

  notifyUnlockResult(deviceId: string, payload: any) {
    this.server.to(deviceId).emit('unlock_result', payload);
  }
}