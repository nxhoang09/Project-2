import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.MQTT,
    options: {
      url: process.env.MQTT_URL || 'mqtt://localhost:1883',
      clientId: process.env.MQTT_CLIENT_ID || 'nest_server_01',
    },
  });

  await app.startAllMicroservices();
  await app.listen(3000);
  
  console.log(`HTTP Server đang chạy tại: http://localhost:3000`);
  console.log(`MQTT Client đã kết nối tới Mosquitto Local`);
}
bootstrap();