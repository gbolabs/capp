import { HttpClient } from '@angular/common/http';
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DbotComponent } from "./dbot/dbot.component";

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
  imports: [CommonModule, DbotComponent, DbotComponent]
})
export class AppComponent {
  title = 'labweb';
  TraceParentHeader = '';
  TraceParent = '';
  TraceSpan = '';
  loading = false;

  constructor(private readonly http: HttpClient) { }

  onButtonClick() {
    this.loading = true; // Start spinner
    console.log('Button clicked!');

    // Use HttpClient instead of fetch()
    this.http.get<OtDiagApiResponse>('http://localhost:5058/api/opentelemetry').subscribe({
      next: (response)=> {
        this.TraceParentHeader = response.traceParentHeader || 'No traceparent header found';
        this.TraceParent = response.traceParent || 'No traceparent found';
        this.TraceSpan = response.traceSpan || 'No tracespan found';
      },
      error: (error) => {
        console.error('Error:', error);
      },
      complete: () => {
        this.loading = false; // Stop spinner
      },
  });
  }
}

interface ApiResponse {
  traceParent?: string;
}
interface OtDiagApiResponse {
  traceParentHeader: string;
  traceParent: string;
  traceSpan: string;
}