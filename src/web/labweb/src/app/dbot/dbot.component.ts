import { Component, OnInit, inject } from '@angular/core';
import { NgFor } from '@angular/common';
import { ProductService, Product } from '../services/product.service';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-dbot',
  standalone: true, // ✅ Required for standalone components
  imports: [NgFor, FormsModule], // ✅ Fixed property name
  templateUrl: './dbot.component.html',
  styleUrls: ['./dbot.component.css'], // ✅ Fixed property name
})
export class DbotComponent implements OnInit {
  private readonly productService = inject(ProductService); // ✅ Dependency Injection

  products: Product[] = []; // ✅ Properly typed array
  name: any;

  ngOnInit() {
    this.load(); // Load products when the component initializes
  }

  load() {
    this.productService.getProducts().subscribe((data) => (this.products = data));
  }

  addProduct() {
    
    let name: string;
    if (!this.name || this.name.trim() === '') {
      // Random name if no name is provided
      name = "Product-" + Math.floor(Math.random() * 1000);
    }else{
      name = this.name;
    }

    const newProduct: Product = { name: name };
    this.productService.addProduct(newProduct).subscribe(() => {
      this.load();
      this.name = ''; // ✅ Clear input after adding
    });
  }

  deleteEntry(id: number | undefined) {
    if (!id) {
      return;
    }
    this.productService.deleteProduct(id).subscribe(() => this.load());
  }
}
