import { HttpClient } from '@angular/common/http';
import { Component, EnvironmentInjector, EnvironmentProviders } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { faker, PersonModule } from '@faker-js/faker';
import { environment } from '../../environments/environment.development';

@Component({
  selector: 'app-otuser',
  imports: [FormsModule],
  templateUrl: './otuser.component.html',
  styleUrl: './otuser.component.css'
})
export class OtuserComponent {
  httpClient: HttpClient;

  constructor(httpClient: HttpClient) {
    this.httpClient = httpClient;
    this.userName = faker.person.fullName();
  }
  apiResponse: any;
  showName() {
    // API /api/opentelemetry with x-user-id header
    this.userName = faker.person.fullName();
    console.log('User name:', this.userName);
    this.httpClient.get(environment.apiBaseUrl + '/api/opentelemetry', {
      headers: { 'x-user-id': this.userName ?? 'unknown' }
    }).subscribe({});
  }
  userName: string | undefined;
}