import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';
import { v4 as uuidv4 } from 'uuid';

const instanceId = uuidv4();
console.log(`Application instance ID: ${instanceId}`);

bootstrapApplication(AppComponent,appConfig)
  .catch((err) => console.error(err));

  export { instanceId };
