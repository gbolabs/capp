import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Product {
  id?: number; // Optional for new products
  name: string;
}

@Injectable({
  providedIn: 'root',
})
export class ProductService {
  private apiUrl = 'http://localhost:5058/api/products'; // Change URL as needed

  private http = inject(HttpClient); // ✅ Angular 19 style injection

  // GET all products
  getProducts(): Observable<Product[]> {
    return this.http.get<Product[]>(this.apiUrl);
  }

  // PUT: Insert a new product
  addProduct(product: Product): Observable<Product> {
    return this.http.put<Product>(this.apiUrl, product);
  }

  // DELETE: Remove a product by ID
  deleteProduct(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
